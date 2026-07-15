package com.weather.service;

import java.util.HashMap;
import java.util.Map;

/**
 * Manual overrides for cities whose default pinyin lookup is unreliable
 * (polyphonic characters, uncommon API matching, etc.).
 */
public final class ChineseCityAliases {

    private static final Map<String, String> ALIASES = new HashMap<>();

    static {
        put("北京", "Beijing");
        put("上海", "Shanghai");
        put("天津", "Tianjin");
        put("重庆", "Chongqing");
        put("香港", "Hong Kong");
        put("澳门", "Macau");
        put("台北", "Taipei");
        put("哈尔滨", "Harbin");
        put("长春", "Changchun");
        put("沈阳", "Shenyang");
        put("呼和浩特", "Hohhot");
        put("石家庄", "Shijiazhuang");
        put("太原", "Taiyuan");
        put("济南", "Jinan");
        put("郑州", "Zhengzhou");
        put("南京", "Nanjing");
        put("杭州", "Hangzhou");
        put("合肥", "Hefei");
        put("福州", "Fuzhou");
        put("南昌", "Nanchang");
        put("武汉", "Wuhan");
        put("长沙", "Changsha");
        put("广州", "Guangzhou");
        put("南宁", "Nanning");
        put("海口", "Haikou");
        put("成都", "Chengdu");
        put("贵阳", "Guiyang");
        put("昆明", "Kunming");
        put("拉萨", "Lhasa");
        put("西安", "Xi'an");
        put("兰州", "Lanzhou");
        put("西宁", "Xining");
        put("银川", "Yinchuan");
        put("乌鲁木齐", "Urumqi");
        put("深圳", "Shenzhen");
        put("苏州", "Suzhou");
        put("青岛", "Qingdao");
        put("大连", "Dalian");
        put("厦门", "Xiamen");
        put("宁波", "Ningbo");
        put("无锡", "Wuxi");
        put("东莞", "Dongguan");
        put("佛山", "Foshan");
        put("惠州", "Huizhou");
        put("珠海", "Zhuhai");
        put("中山", "Zhongshan");
        put("汕头", "Shantou");
        put("温州", "Wenzhou");
        put("嘉兴", "Jiaxing");
        put("绍兴", "Shaoxing");
        put("金华", "Jinhua");
        put("台州", "Taizhou");
        put("常州", "Changzhou");
        put("南通", "Nantong");
        put("徐州", "Xuzhou");
        put("扬州", "Yangzhou");
        put("镇江", "Zhenjiang");
        put("盐城", "Yancheng");
        put("淮安", "Huaian");
        put("连云港", "Lianyungang");
        put("泰州", "Taizhou");
        put("宿迁", "Suqian");
        put("烟台", "Yantai");
        put("潍坊", "Weifang");
        put("临沂", "Linyi");
        put("淄博", "Zibo");
        put("济宁", "Jining");
        put("威海", "Weihai");
        put("东营", "Dongying");
        put("日照", "Rizhao");
        put("泰安", "Tai'an");
        put("聊城", "Liaocheng");
        put("德州", "Dezhou");
        put("滨州", "Binzhou");
        put("菏泽", "Heze");
        put("洛阳", "Luoyang");
        put("开封", "Kaifeng");
        put("新乡", "Xinxiang");
        put("南阳", "Nanyang");
        put("安阳", "Anyang");
        put("许昌", "Xuchang");
        put("平顶山", "Pingdingshan");
        put("焦作", "Jiaozuo");
        put("保定", "Baoding");
        put("唐山", "Tangshan");
        put("秦皇岛", "Qinhuangdao");
        put("邯郸", "Handan");
        put("邢台", "Xingtai");
        put("廊坊", "Langfang");
        put("沧州", "Cangzhou");
        put("承德", "Chengde");
        put("张家口", "Zhangjiakou");
        put("衡水", "Hengshui");
        put("包头", "Baotou");
        put("鄂尔多斯", "Ordos");
        put("赤峰", "Chifeng");
        put("大同", "Datong");
        put("运城", "Yuncheng");
        put("临汾", "Linfen");
        put("宝鸡", "Baoji");
        put("咸阳", "Xianyang");
        put("渭南", "Weinan");
        put("延安", "Yan'an");
        put("榆林", "Yulin");
        put("汉中", "Hanzhong");
        put("绵阳", "Mianyang");
        put("德阳", "Deyang");
        put("宜宾", "Yibin");
        put("南充", "Nanchong");
        put("泸州", "Luzhou");
        put("乐山", "Leshan");
        put("遵义", "Zunyi");
        put("曲靖", "Qujing");
        put("大理", "Dali");
        put("丽江", "Lijiang");
        put("西双版纳", "Xishuangbanna");
        put("桂林", "Guilin");
        put("柳州", "Liuzhou");
        put("北海", "Beihai");
        put("三亚", "Sanya");
        put("泉州", "Quanzhou");
        put("漳州", "Zhangzhou");
        put("莆田", "Putian");
        put("三明", "Sanming");
        put("南平", "Nanping");
        put("龙岩", "Longyan");
        put("宁德", "Ningde");
        put("赣州", "Ganzhou");
        put("九江", "Jiujiang");
        put("上饶", "Shangrao");
        put("宜春", "Yichun");
        put("景德镇", "Jingdezhen");
        put("襄阳", "Xiangyang");
        put("宜昌", "Yichang");
        put("荆州", "Jingzhou");
        put("黄冈", "Huanggang");
        put("十堰", "Shiyan");
        put("株洲", "Zhuzhou");
        put("湘潭", "Xiangtan");
        put("衡阳", "Hengyang");
        put("岳阳", "Yueyang");
        put("常德", "Changde");
        put("郴州", "Chenzhou");
        put("张家界", "Zhangjiajie");
        put("韶关", "Shaoguan");
        put("湛江", "Zhanjiang");
        put("江门", "Jiangmen");
        put("肇庆", "Zhaoqing");
        put("清远", "Qingyuan");
        put("揭阳", "Jieyang");
        put("梅州", "Meizhou");
        put("潮州", "Chaozhou");
        put("鞍山", "Anshan");
        put("抚顺", "Fushun");
        put("本溪", "Benxi");
        put("丹东", "Dandong");
        put("锦州", "Jinzhou");
        put("营口", "Yingkou");
        put("辽阳", "Liaoyang");
        put("盘锦", "Panjin");
        put("铁岭", "Tieling");
        put("朝阳", "Chaoyang");
        put("葫芦岛", "Huludao");
        put("吉林", "Jilin");
        put("四平", "Siping");
        put("通化", "Tonghua");
        put("松原", "Songyuan");
        put("白城", "Baicheng");
        put("齐齐哈尔", "Qiqihar");
        put("大庆", "Daqing");
        put("牡丹江", "Mudanjiang");
        put("佳木斯", "Jiamusi");
        put("克拉玛依", "Karamay");
        put("喀什", "Kashgar");
        put("吐鲁番", "Turpan");
        put("嘉峪关", "Jiayuguan");
        put("酒泉", "Jiuquan");
        put("天水", "Tianshui");
        put("芜湖", "Wuhu");
        put("蚌埠", "Bengbu");
        put("淮南", "Huainan");
        put("马鞍山", "Ma'anshan");
        put("安庆", "Anqing");
        put("黄山", "Huangshan");
        put("滁州", "Chuzhou");
        put("阜阳", "Fuyang");
        put("宿州", "Suzhou");
        put("六安", "Lu'an");
        put("亳州", "Bozhou");
        put("池州", "Chizhou");
        put("宣城", "Xuancheng");
    }

    private static void put(String zh, String en) {
        ALIASES.put(zh, en);
    }

    private ChineseCityAliases() {
    }

    public static String toEnglish(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return null;
        }
        String key = normalize(keyword);
        String mapped = ALIASES.get(key);
        if (mapped != null) {
            return mapped;
        }
        return ChinesePinyin.toCompact(key);
    }

    /** Mapped English only (no pinyin fallback). */
    public static String mappedEnglish(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return null;
        }
        return ALIASES.get(normalize(keyword));
    }

    static String normalize(String keyword) {
        return keyword.trim()
                .replace("市", "")
                .replace("省", "")
                .replace("地区", "")
                .replace("自治州", "")
                .replace("自治区", "")
                .replace("特别行政区", "");
    }
}